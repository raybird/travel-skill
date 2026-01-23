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

## Rate Limits and Access

- Most government APIs are free and open
- Some require simple registration
- No authentication required for most endpoints
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
