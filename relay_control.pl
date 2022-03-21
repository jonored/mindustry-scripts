
pipe(NEEDSLINK, OUT);

$rv = fork();

if($rv == 0) {
        close(OUT);
        @lines = <NEEDSLINK>;
        for (@lines) {
                if (/^(\w+): */) {
                        $LABEL{$1}=$lineno;
                        s/^(\w+): *//;
                }
                s/jump \+(\d)+/"jump " . ($lineno+$1)/ge;
                $lineno = $lineno + 1;
        }
        for (@lines) {
                for $label (keys(%LABEL)) {
                        s/$label/$LABEL{$label}/g;
                }
                s/^\s*//;
                chomp;
        }
        $,="\r\n";
        print @lines;
        exit(0);
}

close(NEEDSLINK);
select OUT;

@resources = split( / /, "copper lead metaglass graphite sand coal titanium thorium scrap silicon plastanium phase-fabric surge-alloy spore-pod blast-compound pyratite itemCapacity" );
@fields = (@resources, "asOfTick", "locked");
@field_indices = 0..$#fields;
@fieldno{@fields} = @field_indices;
%factories = (
    "graphite-press" => {"resource" => "graphite"},
    "multi-press" => {"resource" => "graphite"},
    "silicon-smelter" => {"resource" => "silicon"},
    "silicon-crucible" => {"resource" => "silicon"},
    "kiln" => {"resource" => "metaglass"},
    "plastanium-compressor" => {"resource" => "plastanium"},
    "phase-weaver" => {"resource" => "phase-fabric"},
    "alloy-smelter" => {"resource" => "surge-alloy"},
    "pyratite-mixer" => {"resource" => "pyratite"},
    "blast-mixer" => {"resource" => "blast-compound"},
    "pulverizer" => {"resource" => "sand"},
    "coal-centrifuge" => {"resource" => "coal"},
);

# Print amounts

for (@resources) {
        print "print \"$_:\"\nprint $_\nprint \"\\n\"\n";
}
print "printflush message1\n";
# Next link
print <<EOF
op add currentLink currentLink 1
op mod currentLink currentLink \@links
getlink currentBlock currentLink
sensor currentType currentBlock \@type
jump 0 equal currentType \@message
EOF
;
# Switch on link currentType:
# if memory cell,
# skip if locked,
print <<EOF
jump MAYBECORE notEqual currentType \@memory-cell
read locked currentBlock ${\($fieldno{"locked"})}
jump 0 greaterThan locked \@tick
op add result \@tick 30
write result currentBlock ${\($fieldno{"locked"})}
read asOfTick currentBlock ${\($fieldno{"asOfTick"})}
EOF
;
# write if I'm newer
print "jump READCELL greaterThan asOfTick bestAsOfTick\n";
print "set locked 0\n";
print "set asOfTick bestAsOfTick\n";
for (@fields) {
        print "write $_ currentBlock ${\($fieldno{$_})}\n";
}
# read if I'm older
print "jump 0 always x false\n";
print "READCELL: ";
for (@fields) {
        print "read $_ currentBlock ${\($fieldno{$_})}\n";
}
print "set bestAsOfTick asOfTick\n";
# if not an unloader,
print <<EOF
MAYBECORE: jump ISCORE equal currentType \@core-nucleus
jump ISCORE equal currentType \@core-foundation
jump HANDLEPROD notEqual currentType @core-shard
EOF
;
print "ISCORE: ";
# print "print \"CORE\\n\"\n";
for (@resources) {
        print "sensor $_ currentBlock \@$_\n";
}
print "set bestAsOfTick \@tick\n";
print "jump 0 always x false\n";
print "HANDLEPROD: jump UNLOADER equal currentType \@unloader\n";
# switch on factory currentType:
for (keys(%factories)) {
# enable if not full.
        print <<EOF
        jump +4 notEqual currentType \@$_
        op lessThan enable? ${\($factories{$_}->{"resource"})} itemCapacity
        control enabled currentBlock enable? 0 0 0
        jump 0 always x false
EOF
        ;
}
# If an unloader,
print "UNLOADER: sensor cfg currentBlock \@config\n";
# read the correct variable for config
print "op div halfCapacity itemCapacity 2\n";
for (@resources) {
        print "jump +2 notEqual cfg \@$_\n";
        print "op greaterThan enable $_ halfCapacity\n";
}
# enable if more than half full 
print "control enabled currentBlock enable 0 0 0\n";
print "jump 0 always x false\n";




