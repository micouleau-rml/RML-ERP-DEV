(() => {
  const form = $('gpsForm');
  const fields = form.elements;
  const visits = $('gpsVisits');
  const status = $('gpsStatus');
  const time = new Intl.DateTimeFormat('fr-FR', {hour:'2-digit', minute:'2-digit'});
  let revision = 0;
  let mapsLoader;
  let owner;

  function invalidate() {
    revision++;
    $('gpsResult').hidden = true;
    $('gpsStops').replaceChildren();
    $('gpsMap').replaceChildren();
    status.textContent = '';
  }

  function fillDirectory(row) {
    const select = row.querySelector('select');
    const previous = select.value;
    select.replaceChildren(new Option('Saisie manuelle', ''));
    for (const [kind, records, address] of [
      ['Chantier', hasPerm('chantiers') ? db.chantiers : [], rmlBLJobAddress],
      ['Client', hasPerm('clients') ? db.clients : [], rmlV421Address]
    ]) {
      for (const record of records) {
        const location = address(record);
        if (!location) continue;
        const name = record.nom || record.name || location;
        const option = new Option(kind + ' · ' + name + ' — ' + location, kind + ':' + record.id);
        option.dataset.name = name;
        option.dataset.address = location;
        select.add(option);
      }
    }
    select.value = previous;
    if (select.selectedIndex < 0) select.selectedIndex = 0;
  }

  function updateFields() {
    const custom = fields.origin.value === 'address';
    $('gpsOriginAddress').style.display = custom ? '' : 'none';
    fields.address.required = custom;
    fields.depot.required = fields.origin.value === 'depot' || fields.roundtrip.checked;
  }

  function addVisit() {
    if (visits.children.length >= 20) {
      status.textContent = 'La tournée est limitée à 20 rendez-vous.';
      return;
    }
    const row = document.createElement('fieldset');
    row.className = 'gps-row';
    row.innerHTML = `<legend>Rendez-vous</legend><div class="gps-fields">
      <label>Client ou chantier <select data-field="directory"></select></label>
      <label>Libellé <input data-field="name" maxlength="100"></label>
      <label>Adresse <input data-field="address" maxlength="240" required></label>
      <label>Durée sur place (min) <input data-field="duration" type="number" value="30" min="1" max="720" required></label>
      <label>Horaire <select data-field="mode"><option value="free">Libre</option><option value="fixed">Heure fixe</option><option value="window">Créneau</option></select></label>
      <label style="display:none">Début <input data-field="start" type="time"></label>
      <label style="display:none">Fin du créneau <input data-field="end" type="time"></label>
    </div><label class="gps-check"><input data-field="done" type="checkbox"> Visite effectuée</label>
    <button type="button">Retirer</button>`;
    const field = key => row.querySelector('[data-field="' + key + '"]');
    fillDirectory(row);
    field('directory').onchange = () => {
      const option = field('directory').selectedOptions[0];
      if (!option?.value) return;
      field('name').value = option.dataset.name;
      field('address').value = option.dataset.address;
    };
    function updateVisit() {
      const done = field('done').checked;
      for (const input of row.querySelectorAll('.gps-fields input, .gps-fields select')) input.disabled = done;
      for (const [key, visible] of [['start', field('mode').value !== 'free'], ['end', field('mode').value === 'window']]) {
        field(key).parentElement.style.display = visible ? '' : 'none';
        field(key).required = visible;
      }
    }
    field('mode').onchange = updateVisit;
    field('done').onchange = updateVisit;
    row.querySelector('button').onclick = () => { row.remove(); invalidate(); };
    visits.append(row);
    invalidate();
  }

  function setDepartureNow() {
    const now = new Date();
    const local = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString();
    fields.date.value = local.slice(0, 10);
    fields.departure.value = local.slice(11, 16);
  }

  function position() {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) return reject(new Error('La géolocalisation est indisponible.'));
      navigator.geolocation.getCurrentPosition(
        ({coords}) => resolve({lat:coords.latitude, lng:coords.longitude}),
        () => reject(new Error('Position introuvable. Autorisez la géolocalisation ou saisissez une adresse.')),
        {timeout:10000}
      );
    });
  }

  function loadMaps(key) {
    if (!key) throw new Error('La clé Google Maps de la carte reste à configurer.');
    if (!mapsLoader) {
      mapsLoader = new Promise((resolve, reject) => {
        const script = document.createElement('script');
        window.rmlGpsMapsReady = resolve;
        script.src = 'https://maps.googleapis.com/maps/api/js?' + new URLSearchParams({
          key, loading:'async', callback:'rmlGpsMapsReady', language:'fr', region:'FR'
        });
        script.onerror = () => {
          script.remove();
          reject(new Error('Impossible de charger la carte Google Maps.'));
        };
        document.head.append(script);
      }).catch(error => { mapsLoader = undefined; throw error; });
    }
    return mapsLoader;
  }

  async function drawMap(data, request) {
    await loadMaps(data.mapKey);
    const [{Map, Polyline}, {AdvancedMarkerElement, PinElement}, {encoding}] = await Promise.all([
      google.maps.importLibrary('maps'), google.maps.importLibrary('marker'), google.maps.importLibrary('geometry')
    ]);
    if (request !== revision) return;
    const map = new Map($('gpsMap'), {
      center:{lat:46.6,lng:2.5}, zoom:6, mapId:data.mapId, streetViewControl:false
    });
    const bounds = new google.maps.LatLngBounds();
    const path = data.polyline ? encoding.decodePath(data.polyline) : [];
    for (const point of path) bounds.extend(point);
    new Polyline({map, path, strokeColor:'#1768ae', strokeWeight:5});
    const markers = [data.origin, ...data.stops.map(stop => stop.point)];
    if (data.end) markers.push(data.end);
    markers.forEach((point, i) => {
      const glyph = i === 0 ? 'D' : i > data.stops.length ? 'R' : String(i);
      const marker = new AdvancedMarkerElement({map, position:point, title:i === 0 ? 'Départ' : i > data.stops.length ? 'Retour' : 'Rendez-vous ' + i});
      marker.append(new PinElement({glyphText:glyph}));
      bounds.extend(point);
    });
    map.fitBounds(bounds, 40);
    google.maps.event.addListenerOnce(map, 'idle', () => {
      if (map.getZoom() > 16) map.setZoom(16);
    });
  }

  function showResult(data, pending, depot, request) {
    const format = value => time.format(new Date(value));
    const distance = new Intl.NumberFormat('fr-FR', {maximumFractionDigits:1}).format(data.meters / 1000);
    $('gpsTotals').textContent = data.stops.length
      ? distance + ' km · ' + Math.round(data.travelSeconds / 60) + ' min de conduite · Fin estimée à ' + format(data.finish)
      : 'Aucun rendez-vous placé dans la tournée.';
    function appendStop(label, destination) {
      const item = document.createElement('li');
      item.append(label + ' ');
      const link = document.createElement('a');
      link.href = 'https://www.google.com/maps/dir/?' + new URLSearchParams({api:'1', destination, travelmode:'driving', dir_action:'navigate'});
      link.textContent = 'Lancer le guidage';
      link.target = '_blank';
      link.rel = 'noopener';
      item.append(link);
      $('gpsStops').append(item);
    }
    for (const stop of data.stops) {
      const visit = pending[stop.index];
      const late = visit.end && Date.parse(stop.start) > Date.parse(visit.end) + 999;
      appendStop(format(stop.start) + ' · ' + (visit.name || visit.address) + (late ? ' · Hors créneau' : ''), stop.point.lat + ',' + stop.point.lng);
    }
    if (data.end && data.stops.length) appendStop(format(data.finish) + ' · Retour au dépôt · ' + depot, data.end.lat + ',' + data.end.lng);
    $('gpsSkipped').textContent = data.skipped.length
      ? 'Rendez-vous non placés : ' + data.skipped.map(i => pending[i].name || pending[i].address).join(' · ')
      : '';
    $('gpsMapStatus').textContent = '';
    $('gpsResult').hidden = false;
    status.textContent = data.trafficConflict
      ? 'La circulation estimée peut empêcher de tenir un créneau. Vérifiez les horaires avant de partir.'
      : 'Calcul terminé avec les estimations de circulation.';
    drawMap(data, request).catch(error => {
      if (revision === request) $('gpsMapStatus').textContent = error.message;
    });
  }

  form.onsubmit = async event => {
    event.preventDefault();
    invalidate();
    const request = revision;
    const date = fields.date.value;
    const at = value => new Date(date + 'T' + value).toISOString();
    const depot = fields.depot.value.trim();
    const origin = fields.origin.value;
    const address = fields.address.value.trim();
    const roundtrip = fields.roundtrip.checked;
    const button = $('gpsCalculate');
    button.disabled = true;
    status.textContent = 'Calcul de la tournée…';
    try {
      const departure = at(fields.departure.value);
      const finish = at(fields.finish.value);
      if (finish <= departure || Date.parse(finish) <= Date.now()) throw new Error('Vérifiez la date et les heures de la tournée.');
      if ((origin === 'depot' || roundtrip) && !depot) throw new Error('Saisissez l’adresse exacte du dépôt.');
      if (origin === 'address' && !address) throw new Error('Saisissez une adresse de départ.');
      const pending = Array.from(visits.children).flatMap(row => {
        const field = key => row.querySelector('[data-field="' + key + '"]');
        if (field('done').checked) return [];
        const mode = field('mode').value;
        const visit = {name:field('name').value.trim(), address:field('address').value.trim(), duration:Number(field('duration').value)};
        if (!visit.address) throw new Error('Chaque rendez-vous doit avoir une adresse.');
        if (mode !== 'free') {
          visit.start = at(field('start').value);
          visit.end = mode === 'fixed' ? visit.start : at(field('end').value);
          if (visit.end < visit.start) throw new Error('La fin du créneau doit suivre son début.');
        }
        return [visit];
      });
      if (!pending.length) throw new Error('Ajoutez au moins un rendez-vous restant.');
      const start = origin === 'position' ? await position() : origin === 'depot' ? depot : address;
      if (revision !== request) return;
      const {data, error} = await sb.functions.invoke('tournee-gps', {
        body:{start, end:roundtrip ? depot : undefined, departure, finish, visits:pending.map(({address, duration, start, end}) => ({address, duration, start, end}))}
      });
      if (revision !== request) return;
      if (error) {
        const response = await error.context?.json?.().catch(() => null);
        throw new Error(response?.error || 'Le service GPS est indisponible. Vérifiez sa configuration.');
      }
      showResult(data, pending, depot, request);
    } catch (error) {
      if (revision === request) status.textContent = error.message;
    } finally {
      button.disabled = false;
    }
  };

  $('gpsOriginAddress').hidden = false;
  form.oninput = () => { invalidate(); updateFields(); };
  $('gpsAdd').onclick = addVisit;
  $('gpsNow').onclick = () => { setDepartureNow(); invalidate(); };
  window.rmlGpsReset = () => {
    form.reset();
    visits.replaceChildren();
    owner = undefined;
    invalidate();
  };
  window.rmlGpsOpen = () => {
    if (owner !== currentUser?.id || !fields.date.value) {
      window.rmlGpsReset();
      owner = currentUser?.id;
      setDepartureNow();
      addVisit();
    }
    for (const row of visits.children) fillDirectory(row);
    updateFields();
  };
})();
