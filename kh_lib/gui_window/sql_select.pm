package gui_window::sql_select;
use base qw(gui_window);
use gui_jchar;
use gui_airborne;
use gui_hlist;
use mysql_exec;

use strict;
use Tk;
use Tk::HList;
use DBI;
#use DBD::MySQL;
use NKF;

#----------------#
#   Window描画   #
#----------------#

sub _new{
	
#--------------#
#   入力部分   #

	my $self = shift;
	my $win = $::main_gui->mw->Toplevel;
	$win->title(Jcode->new('SQL文 (SELECT) 実行')->sjis);
	$self->{win_obj} = $win;

	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'y');

	my $t = $lf->Scrolled(
		'Text',
		spacing1 => 0,
		spacing2 => 0,
		spacing3 => 0,
		-scrollbars=> 'osoe',
		-height => 8,
		-width => 48,
		-wrap => 'none',
		-font => "TKFN",
	)->pack(-fill=>'both',-expand=>'yes',pady => 2);
	$t->focus;
	$t->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$t]);

	$lf->Label(
		-text => Jcode->new('最大表示数:')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	my $e = $lf->Entry(
		-font  => "TKFN",
		-width => 5,
	)->pack(-side => 'left');
	$e->insert(0,'1000');

	$lf->Button(
		-text    => Jcode->new('実行')->sjis,
		-command => sub {$self->exec;},
		-font    => "TKFN"
	)->pack(-side => "right");


#----------------#
#   結果表示部   #

	my $plane = gui_airborne->make(
		parent      => $win,
		parent_name => $self->win_name,
		tower       => $lf,
		title       => Jcode->new('SQL文 (SELECT) 結果')->sjis,
	);

	my $lf2 = $plane->frame->LabFrame(
		-label       => 'Result',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'y');
	my $field = $lf2->Frame()->pack(-fill => 'both', -expand => 'y');

	my $list = $field->Scrolled('HList',
		-scrollbars       => 'osoe',
		-header           => '1',
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => '1',
		-padx             => '2',
		-background       => 'white',
		-height           => '4',
	)->pack(-fill=>'both',-expand => 'yes');

	my $frame = $lf2->Frame()->pack(-fill => 'x', -expand => '0');

	$frame->Button(
		-text    => Jcode->new('コピー')->sjis,
		-command => sub {gui_hlist->copy($self->list);},
		-font    => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	my $label = $frame->Label(
		-text => Jcode->new('　出力された行数: ')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$plane->make_control($frame);

	$self->{entry} = $e;
	$self->{text}  = $t;
	$self->{list}  = $list;
	$self->{label} = $label;
	$self->{plane} = $plane;
	$self->{field} = $field;
	
	return $self;
}

#--------------#
#   イベント   #
#--------------#

#--------------#
#   検索実行   #

sub exec{
	my $self = shift;
	my $t = mysql_exec->select(Jcode->new($self->text->get("1.0","end"))->euc);
	
	# エラーチェック
	if ( $t->err ){
		my $msg = "SQL文にエラーがありました。\n\n".$t->err;
		my $w = $self->win_obj;
		gui_errormsg->open(
			type   => 'msg',
			msg    => $msg,
			window => \$w
		);
		return 0;
	}
	
	# 結果の書き出し
	$self->list->destroy;                                   # 入れ物
	$self->{list} = $self->field->Scrolled('HList',
		-scrollbars       => 'oe',
		-header           => '1',
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => $t->hundle->{NUM_OF_FIELDS},
		-padx             => '2',
		-background       => 'white',
		-height           => '4',
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended'
	)->pack(-fill=>'both',-expand => 'yes');
	my $n = 0;
	foreach my $i (@{$t->hundle->{NAME}}){
		$self->list->header('create',$n,-text => $i);
		++$n;
	}
	
	my $row = 0;                                            # 中身
	my $max = $self->max; my $frag = 0;
	while (my $i = $t->hundle->fetch){
		$self->list->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			$self->list->itemCreate($row,$col,-text => nkf('-s -E',$h));
			++$col;
		}
		++$row;
		if ($row == $max){
			$frag = 1;
			last;
		}
	}
	if ($frag){                                             # 出力行数カウント
		while (my $i = $t->hundle->fetch){
			++$row;
		}
	}
	$self->label->configure(-text,Jcode->new('出力された行数: '."$row")->sjis);
	
	$self->plane->frame->focus;
}


sub close{
	my $self = shift;
	$self->plane->close;
}

sub start{
	my $self = shift;
	$self->plane->start;
}
#--------------#
#   アクセサ   #
#--------------#

sub max{
	my $self = shift;
	return $self->{entry}->get;
}

sub text{
	my $self = shift;
	return $self->{text};
}

sub list{
	my $self = shift;
	return $self->{list};
}

sub field{
	my $self = shift;
	return $self->{field};
}

sub label{
	my $self = shift;
	return $self->{label};
}


sub win_name{
	return 'w_tool_sql_select';
}

sub plane{
	my $self = shift;
	return $self->{plane};
}


1;
