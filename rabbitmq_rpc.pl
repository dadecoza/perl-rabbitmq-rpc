#!/usr/bin/perl -w
use Net::AMQP::RabbitMQ;

sub rpc_call {
    my $host = shift;
    my $user = shift;
    my $pass = shift;
    my $queue = shift;
    my $payload = shift;
    my $cid;
    my @chars = ("A".."Z", "a".."z", 0..9);
    $cid .= $chars[rand @chars] for 1..8;
    my $mq = Net::AMQP::RabbitMQ->new();
    $mq->connect($host, { user => $user, password => $pass });
    $mq->channel_open(1);
    $mq->channel_open(2);
    $mq->queue_declare(1, $queue, {auto_delete => 0, exclusive => 0});
    my $rq = $mq->queue_declare(2, "", {auto_delete => 1, exclusive => 1});
    $mq->publish(1, $queue, $payload, undef, {reply_to => $rq, correlation_id => $cid});
    my $timeout = 5 + time; # 5 second timeout
    my $message;
    while (not $message and (time < $timeout)) {
        my $gotten = $mq->get(2, $rq, {no_ack => 1});
        my $correlation_id = $gotten->{props}->{correlation_id};
        if ($correlation_id and ($correlation_id eq $cid)) {
            $message = $gotten->{body};
        }
    }
    $mq->disconnect();
    return $message
}

print rpc_call("rabbitmqserver","integration","secret","getuserinfo", "scott");
