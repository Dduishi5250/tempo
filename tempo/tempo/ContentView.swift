// ContentView.swift

import SwiftUI
import CoreLocation

// MARK: - 날씨 데이터 모델
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

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation? {
        didSet {
            if let location = currentLocation {
                fetchWeather(for: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        }
    }
    @Published var weatherData: WeatherResponse? {
        didSet {
            // 날씨 데이터가 업데이트될 때마다 앱 그룹에 저장
            saveWeatherDataToAppGroup()
        }
    }

    private let apiKey = "14494c4f25ac1c5c41b1be4377337dfe"
    private let appGroupId = "group.com.yourcompany.tempo"
    private let weatherDataKey = "savedWeatherData" //

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("위치 권한 승인됨")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("위치 권한 거부 또는 제한됨")
        case .notDetermined:
            print("위치 권한 결정되지 않음")
        @unknown default:
            print("알 수 없는 위치 권한 상태")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if self.currentLocation == nil {
            self.currentLocation = location
            print("현재 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 정보 가져오기 실패: \(error.localizedDescription)")
    }

    // MARK: - 날씨 데이터 가져오기 함수
    func fetchWeather(for latitude: Double, longitude: Double) {
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENWEATHERMAP_API_KEY" else {
            print("OpenWeatherMap API 키를 설정해주세요.")
            return
        }

        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=kr"
        guard let url = URL(string: urlString) else {
            print("잘못된 URL: \(urlString)")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in // [weak self] 추가
            guard let self = self else { return } // self 참조 유지

            if let error = error {
                print("네트워크 요청 오류: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("서버 응답 오류: \(response?.description ?? "알 수 없는 응답")")
                return
            }

            guard let data = data else {
                print("데이터 없음")
                return
            }

            do {
                let decoder = JSONDecoder()
                let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)

                DispatchQueue.main.async {
                    self.weatherData = weatherResponse // didSet 블록이 호출되어 데이터 저장
                    print("날씨 데이터 성공적으로 가져옴: \(weatherResponse.name), \(weatherResponse.main.temp)°C")
                }
            } catch {
                print("JSON 디코딩 오류: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("받은 JSON 데이터: \(jsonString)")
                }
            }
        }.resume()
    }

    // MARK: - 앱 그룹에 날씨 데이터 저장 함수
    private func saveWeatherDataToAppGroup() {
        guard let weatherData = weatherData else { return }
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(weatherData) // WeatherResponse 객체를 Data로 인코딩

            if let userDefaults = UserDefaults(suiteName: appGroupId) {
                userDefaults.set(encodedData, forKey: weatherDataKey) // 앱 그룹 UserDefaults에 저장
                print("날씨 데이터 앱 그룹에 저장 성공!")
            } else {
                print("앱 그룹 UserDefaults 초기화 실패.")
            }
        } catch {
            print("날씨 데이터 인코딩 또는 저장 오류: \(error.localizedDescription)")
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject var locationManager = LocationManager()

    var body: some View {
        VStack {
            if let location = locationManager.currentLocation {
                Text("위도: \(location.coordinate.latitude)")
                Text("경도: \(location.coordinate.longitude)")
            } else {
                Text("위치 정보를 가져오는 중...")
            }

            if let weather = locationManager.weatherData {
                Divider()
                Text("도시: \(weather.name)")
                    .font(.title2)
                Text("현재 온도: \(String(format: "%.1f", weather.main.temp))°C")
                    .font(.headline)
                Text("날씨: \(weather.weather.first?.description ?? "알 수 없음")")
            } else if locationManager.currentLocation != nil {
                Text("날씨 정보를 가져오는 중...")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
