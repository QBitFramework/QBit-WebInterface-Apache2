package QBit::WebInterface::Apache2;

use qbit;

use base qw(QBit::WebInterface);

use Apache2::Connection;
use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::RequestUtil;

use QBit::WebInterface::Apache2::Request;

sub handler : method {
    my ($self, $r) = @_;

    $self = $self->new() unless blessed($self);

    $self->request(QBit::WebInterface::Apache2::Request->new(r => $r));

    $self->build_response();

    $r->err_headers_out->add('Set-Cookie' => $_->as_string()) foreach values(%{$self->response->cookies});

    while (my ($key, $value) = each(%{$self->response->headers})) {
        $r->headers_out->add($key => $value);
    }

    $r->content_type($self->response->content_type);
    $r->headers_out->add(
        'Content-Disposition' => 'attachment; filename="' . $self->_escape_filename($self->response->filename) . '"')
      if $self->response->filename;

    $r->headers_out->add(Location => $self->response->location)
      if $self->response->location;

    eval {
        $r->print(
            ref($self->response->data)
            ? ${$self->response->data}
            : $self->response->data
          )
          if defined($self->response->data);
    };

    my $status = $self->response->status;
    $r->status($status) if defined($status);

    $self->request(undef);
    $self->response(undef);

    return Apache2::Const::OK;
}

TRUE;
