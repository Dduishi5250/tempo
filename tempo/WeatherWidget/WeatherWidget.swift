// WeatherWidget.swift

import WidgetKit
import SwiftUI

// MARK: - 날씨 데이터 모델 ( ContentView.swift에서 정의한 것과 동일하게 붙여넣으세요! )
// 이 부분은 WeatherWidget.swift 파일에도 동일하게 있어야 합니다.
// 날씨 데이터 모델은 메인 앱과 위젯 모두에서 공유해야 하므로,
// 가능하면 별도의 파일 (예: WeatherModel.swift)로 분리하여 두 파일 모두 import 하는 것이 좋지만,
// 지금은 편의상 여기에 다시 붙여넣으셔도 됩니다.
struct WeatherResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let main: Main
    let name: String
    let timezone: Int?
    let dt: Int?
    enum CodingKeys: String, CodingKey {
        case coord, weather, main, name, timezone, dt
    }
}

struct Coord: Codable {
    let lon: Double
    let lat: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
    let humidity: Int
    enum CodingKeys: String, CodingKey {
        case temp, feels_like, temp_min, temp_max, pressure, humidity
    }
}

// MARK: - 위젯 Entry (날씨 데이터 포함)
struct WeatherEntry: TimelineEntry {
    let date: Date
    let weather: WeatherResponse? // 여기에 날씨 데이터를 추가
}

// MARK: - 위젯 Provider (데이터 제공)
struct WeatherProvider: TimelineProvider {
    // 메인 앱의 LocationManager에서 사용한 앱 그룹 ID와 키를 여기에 동일하게 정의합니다.
    private let appGroupId = "group.com.yourcompany.tempo" // <-- 여기에 정확한 앱 그룹 ID 입력!
    private let weatherDataKey = "savedWeatherData" // UserDefaults에 저장할 키 이름

    func placeholder(in context: Context) -> WeatherEntry {
        // 데이터를 가져오기 전에 표시될 기본 위젯 UI (로딩 상태)
        // 실제 데이터가 없으므로 nil을 전달하거나 기본값을 설정합니다.
        WeatherEntry(date: Date(), weather: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> ()) {
        // 위젯 갤러리나 빠르게 UI를 표시할 때 사용되는 스냅샷 데이터
        let entry = WeatherEntry(date: Date(), weather: loadWeatherDataFromAppGroup())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> ()) {
        // 위젯의 타임라인을 정의하여 언제 업데이트될지 결정
        var entries: [WeatherEntry] = []
        let currentDate = Date()

        // 앱 그룹에서 최신 날씨 데이터 로드
        let latestWeather = loadWeatherDataFromAppGroup()

        // 현재 시간을 기준으로 엔트리 생성 (최신 데이터를 바로 반영)
        let entry = WeatherEntry(date: currentDate, weather: latestWeather)
        entries.append(entry)

        // 다음 업데이트 시점 설정 (예: 15분 후)
        // 실제 날씨 위젯은 백그라운드 업데이트 예산이 제한적이므로 너무 자주 업데이트하지 않는 것이 좋습니다.
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate)) // 다음 업데이트는 15분 후에
        completion(timeline)
    }

    // MARK: - 앱 그룹에서 날씨 데이터 로드 함수
    private func loadWeatherDataFromAppGroup() -> WeatherResponse? {
        if let userDefaults = UserDefaults(suiteName: appGroupId) {
            if let savedData = userDefaults.data(forKey: weatherDataKey) {
                do {
                    let decoder = JSONDecoder()
                    let weatherResponse = try decoder.decode(WeatherResponse.self, from: savedData)
                    print("날씨 데이터 앱 그룹에서 로드 성공!")
                    return weatherResponse
                } catch {
                    print("날씨 데이터 디코딩 오류: \(error.localizedDescription)")
                }
            } else {
                print("앱 그룹에서 저장된 날씨 데이터 찾을 수 없음.")
            }
        } else {
            print("앱 그룹 UserDefaults 초기화 실패.")
        }
        return nil
    }
}

// MARK: - 위젯 View
struct WeatherWidgetEntryView : View {
    var entry: WeatherProvider.Entry

    var body: some View {
        ZStack {
            // 배경색 또는 이미지 (선택 사항)
            ContainerRelativeShape()
                .fill(Color.blue.gradient)

            VStack {
                if let weather = entry.weather {
                    Text(weather.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(String(format: "%.1f", weather.main.temp))°C")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(weather.weather.first?.description ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("날씨 정보 없음")
                        .foregroundColor(.white)
                    Text("앱을 실행하여")
                        .foregroundColor(.white)
                    Text("정보를 업데이트하세요.")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - 위젯 구성
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("내 날씨 위젯") // 위젯 선택 시 표시되는 이름
        .description("현재 위치의 날씨 정보를 보여줍니다.") // 위젯 설명
        .supportedFamilies([.systemSmall, .systemMedium]) // 지원하는 위젯 크기
    }
}

// MARK: - 위젯 번들
struct WeatherWidgetBundle1: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
    }
}
