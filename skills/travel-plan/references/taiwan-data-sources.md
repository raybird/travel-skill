# Taiwan Tourism Data Sources

This document lists the available data sources for Taiwan travel information that can be used with the Travel Plan agent.

## Government Open Data Platforms

### 交通部觀光署 (Tourism Administration, MOTC)

**Website**: https://www.taiwan.net.tw/

**Open Data Portal**: https://data.gov.tw/en/datasets/7777

**Available Datasets**:

| Dataset | Format | URL | Description |
|---------|--------|-----|-------------|
| 全台景點 | JSON/XML/CSV | data.gov.tw | Comprehensive attraction database |
| 活動資訊 | JSON/XML | data.gov.tw | Seasonal events and festivals |
| 住宿資料 | JSON/XML | data.gov.tw | Hotels and hostels |
| 餐飲資料 | JSON/XML | data.gov.tw | Restaurants and food |
| 旅客服務中心 | JSON/XML | data.gov.tw | Tourist information centers |

**Data Fields** (Common):
```
- id: Unique identifier
- name: Attraction name
- description: Detailed description
- address: Full address
- tel: Contact phone
- open_time: Opening hours
- lat/lng: Coordinates
- picture: Image URL(s)
- class: Category classification
```

### 縣市別旅遊資料

#### 台北市 (Taipei City)

**Portal**: https://www.travel.taipei/

**Open Data**: https://data.taipei/

| Dataset | Format | Description |
|---------|--------|-------------|
| 景點 | JSON API | Taipei attractions |
| 活動 | JSON API | Taipei events |
| 美食 | JSON API | Taipei restaurants |

#### 台中市 (Taichung City)

**Portal**: https://travel.taichung.gov.tw/

**Open Data**: https://data.taichung.gov.tw/

| Dataset | Format | Description |
|---------|--------|-------------|
| 景點 | CSV/JSON | Taichung attractions |
| 活動 | CSV/JSON | Taichung events |

#### 台南市 (Tainan City)

**Portal**: https://www.tainan.gov.tw/

**Open Data**: https://data.tainan.gov.tw/

| Dataset | Format | Description |
|---------|--------|-------------|
| 景點 | JSON | Tainan attractions (multiple languages) |
| 活動 | JSON | Tainan events |
| 美食 | JSON | Tainan food |

#### 高雄市 (Kaohsiung City)

**Portal**: https://travel.kcg.gov.tw/

**Open Data**: https://data.kcg.gov.tw/

| Dataset | Format | Description |
|---------|--------|-------------|
| 景點 | JSON/API | Kaohsiung attractions |
| 活動 | JSON/API | Kaohsiung events |

#### 花蓮縣 (Hualien County)

**Portal**: https://www.hualien.gov.tw/

**Open Data**: https://data.hualien.gov.tw/

| Dataset | Format | Description |
|---------|--------|-------------|
| 景點 | CSV/JSON | Hualien attractions |
| 活動 | CSV/JSON | Hualien events |

## Weather

### 中央氣象署 (Central Weather Administration, CWA)

**Website**: https://www.cwa.gov.tw/ — human-readable forecasts; point users here when you cannot query the API.

**Open Data Platform**: https://opendata.cwa.gov.tw/ — requires a free member account; every API call needs the member authorization code (`Authorization` query parameter).

**API base**: `https://opendata.cwa.gov.tw/api/v1/rest/datastore/{dataset}`

| Dataset | Description |
|---------|-------------|
| `F-C0032-001` | 一般天氣預報-今明 36 小時天氣預報 (county level) |
| `F-D0047-089` | 鄉鎮天氣預報-臺灣未來 3 天天氣預報 (every 3 hours) |
| `F-D0047-091` | 鄉鎮天氣預報-臺灣未來 1 週天氣預報 |
| `F-D0047-061` / `F-D0047-063` | 鄉鎮天氣預報-臺北市未來 3 天 / 1 週 |
| `F-D0047-073` / `F-D0047-075` | 鄉鎮天氣預報-臺中市未來 3 天 / 1 週 |

Other counties have their own `F-D0047-*` codes; look them up in the API document at https://opendata.cwa.gov.tw/apidoc/v1 rather than guessing.

```bash
curl "https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-D0047-063?Authorization=YOUR_KEY"
```

Record each forecast in the day's `weather` object of the itinerary JSON, with its `source` and `checked_at`. Forecasts change daily; re-check a few days before departure.

## Transportation

### TDX 運輸資料流通服務 (Transport Data eXchange, MOTC)

**Website**: https://tdx.transportdata.tw/

**API base**: `https://tdx.transportdata.tw/api/basic`

Covers MRT (e.g. `/v2/Rail/Metro/Station/TRTC` for Taipei Metro), buses, 台鐵 (`/v3/Rail/TRA/...`), and 高鐵 (`/v2/Rail/THSR/...`) stations and timetables.

**Access**:
- Without an account ("guest mode"): browser access to basic services only, limited to 20 calls per source IP per day
- With a free member account: an API key (Client Id / Client Secret) unlocks the full service; rate limits depend on the subscription plan
- Sample code: https://github.com/tdxmotc/SampleCode

### 高速公路 1968 (Freeway Bureau, MOTC)

**Website**: https://1968.freeway.gov.tw/

Real-time freeway conditions: road network map, section speeds, CCTV, incidents and roadworks, service area status, travel time estimates and forecasts, and congestion rankings. Data refreshes every minute. Use it to compare freeway routes (Planning Rule 4) and to set return-trip buffers before a deadline.

## API Access Examples

### Basic HTTP Request (Generic)

```bash
# Example: Get attractions data
curl -X GET "https://example.com/api/attractions" \
  -H "Accept: application/json" \
  -o attractions.json
```

### Taiwan Tourism Bureau (JSON Example)

```json
{
  "XmlName": "Tourism",
  "ID": "12345",
  "Name": "景點名稱",
  "Description": "景點描述...",
  "Tel": "02-1234-5678",
  "Add": "台北市信義區...",
  "Opentime": "09:00-17:00",
  "Px": 121.564567,
  "Py": 25.033456,
  "Picture1": "https://example.com/image.jpg"
}
```

### Useful Query Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| $filter | Filter by region | `$filter=County eq 'Taipei'` |
| $top | Limit results | `$top=20` |
| $format | Response format | `$format=JSON` |

## Data Quality Notes

### Update Frequency
- Most datasets update daily or weekly
- Check "Changetime" field for last update
- Some local datasets update monthly

### Coverage
- Northern Taiwan: Comprehensive coverage
- Central Taiwan: Good coverage
- Southern Taiwan: Good coverage
- Eastern Taiwan: Good coverage
- Outlying islands: Limited coverage

### Limitations
- Some entries may have incomplete data
- Business status may not be current
- Coordinate accuracy varies
- Photo URLs may change

## Recommended Usage Strategy

1. **Primary Source**: Use 交通部觀光署 as main data source
2. **Local Verification**: Cross-check with city-specific portals
3. **Freshness Check**: Always note the data update timestamp
4. **Fallback**: Have backup sources for popular destinations
5. **Citation**: Record the source and query date for every fact you use, in the itinerary JSON `sources` (`title`, `url`, `checked_at`) or the day's `weather.checked_at`

## Rate Limits and Access

- Most government APIs are free and open
- Tourism datasets on data.gov.tw and city portals generally need no authentication
- CWA and TDX require a free member account and key (see above)
- Check individual portal documentation for limits

## Alternative Data Sources

For additional information, consider:

| Source | Use Case |
|--------|----------|
| Google Places API | Real-time business status |
| TripAdvisor | Reviews and ratings |
| Wikipedia | Historical/cultural context |
| OpenStreetMap | Geographic data |

## Related Documentation

- See [Output Formats](output-formats.md) for how to use this data
- See [Conversation Guide](conversation-guide.md) for presentation tips
