for ((i=1;i<=16;i++));
do
  cmd="cp ${i}/output0.o top-progs/${i}-output0.o"
  ${cmd}
done
