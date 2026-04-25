import Foundation

protocol ContainerProtocol: AnyObject {
    var config: AppConfig { get }
    var authStore: AuthStoring { get }
    var localeStore: LocaleStoring { get }
    var router: AppRouting { get }
}

final class Container: ContainerProtocol {
    let config: AppConfig
    let authStore: AuthStoring
    let localeStore: LocaleStoring
    let router: AppRouting

    init(
        config: AppConfig,
        authStore: AuthStoring,
        localeStore: LocaleStoring,
        router: AppRouting
    ) {
        self.config = config
        self.authStore = authStore
        self.localeStore = localeStore
        self.router = router
    }

    static func bootstrap() throws -> Container {
        let config = try AppConfig.load()
        return Container(
            config: config,
            authStore: AuthStore(),
            localeStore: LocaleStore(),
            router: AppRouter(initial: .login)
        )
    }
}
