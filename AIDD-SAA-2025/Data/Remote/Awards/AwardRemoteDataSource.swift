import Foundation
import os
import RxSwift
import Supabase

protocol AwardRemoteDataSource: AnyObject {
    func fetchTeaser() -> Single<[AwardDTO]>
}

/// Live data source backed by `supabase-swift` Postgres. Bridges the
/// SDK's `async` API into RxSwift `Single` per Constitution III's
/// SDK-boundary discipline.
nonisolated final class AwardRemoteDataSourceImpl: AwardRemoteDataSource {

    private let client: SupabaseClient
    private let scheduler: ImmediateSchedulerType

    init(
        client: SupabaseClient,
        scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    ) {
        self.client = client
        self.scheduler = scheduler
    }

    func fetchTeaser() -> Single<[AwardDTO]> {
        Single<[AwardDTO]>.create { [weak self] observer in
            guard let self else {
                observer(.failure(NSError(
                    domain: "AwardRemoteDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "data source deallocated"]
                )))
                return Disposables.create()
            }
            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    Log.dataSupabase.debug("awards.fetchTeaser: starting query")
                    let response: [AwardDTO] = try await self.client
                        .from("awards")
                        .select()
                        .order("display_order", ascending: true)
                        .limit(6)
                        .execute()
                        .value
                    Log.dataSupabase.debug("awards.fetchTeaser: ok rows=\(response.count, privacy: .public)")
                    observer(.success(response))
                } catch {
                    Log.dataSupabase.error("awards.fetchTeaser: failed error=\(String(describing: error), privacy: .public)")
                    observer(.failure(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }
}
