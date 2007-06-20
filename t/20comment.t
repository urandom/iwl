use Test::More tests => 3;

use IWL::Comment;

{
    my $comment = IWL::Comment->new('I am a comment');

    is($comment->getContent, '<!-- I am a comment -->');
    $comment->setContent('Another comment');
    is($comment->getContent, '<!-- Another comment -->');
    $comment->appendContent('Alpha');
    $comment->prependContent('Foo bar');
    is($comment->getContent, '<!-- Foo bar Another comment Alpha -->');
}
