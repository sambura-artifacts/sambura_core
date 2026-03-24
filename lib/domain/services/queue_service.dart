abstract class QueueService {
  Future<void> publish(String queueName, Map<String, dynamic> message);
}
