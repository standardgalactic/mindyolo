if [ $# != 2 ]
then
    echo "Usage: bash run_train.sh [CONFIG_PATH] [DEVICE_TRAGET] [DEVICE_NUM] [DEVICE_ID|RANK_TABLE_FILE|CUDA_VISIBLE_DEVICES]"
exit 1
fi

get_real_path(){
    if [ "${1:0:1}" == "/" ]; then
        echo $1
    else
        echo "$(realpath -m ${PWD}/$1)"
    fi
}

CONFIG_PATH=$(get_real_path $1)
DEVICE_TRAGET=$2
DEVICE_NUM=$3

PARALLEL=0
if [ $DEVICE_NUM -gt 1 ]; then
    PARALLEL=1
fi

if [ $DEVICE_TRAGET == 'Ascend' ]; then
    echo "Run Ascend"
    if [ $DEVICE_NUM == 1 ]; then
        DEVICE_ID=$4
        export DEVICE_NUM=1
        export DEVICE_ID=$DEVICE_ID
        export RANK_SIZE=1
        export RANK_ID=$DEVICE_ID
    elif [ $DEVICE_NUM == 8 ]; then
        RANK_TABLE_FILE=$4
        export DEVICE_NUM=8
        export RANK_SIZE=8
        export RANK_TABLE_FILE=$RANK_TABLE_FILE
        export MINDSPORE_HCCL_CONFIG_PATH=$RANK_TABLE_FILE
        PARALLEL=1
    else
        echo "error: Ascend device num not equal 1 or 8"
        exit 1
    fi
elif [ $DEVICE_TRAGET == 'GPU' ]; then
    echo "Run GPU"
    export CUDA_VISIBLE_DEVICES=$4
elif [ $DEVICE_TRAGET == "CPU" ]; then
    echo "Run CPU"
    if [ $DEVICE_NUM -gt 1 ]; then
        echo "error: CPU device num not equal 1"
        exit 1
    fi
else
    echo "error: Not support $DEVICE_TRAGET platform."
    exit 1
fi


if [ ! -f $CONFIG_PATH ]; then
    echo "error: CONFIG_PATH=$CONFIG_PATH is not a file"
    exit 1
fi


export RANK_SIZE=$DEVICE_NUM
BASE_PATH=$(cd ./"`dirname $0`" || exit; pwd)
cd $BASE_PATH

if [ $PARALLEL == 1 ]; then
    mpirun --allow-run-as-root -n $RANK_SIZE --output-filename log_output --merge-stderr-to-stdout \
    python ./tools/train.py \
      --device_target=$DEVICE_TRAGET \
      --config=$CONFIG_FILE
      --is_parallel=True > log.txt 2>&1 &
else
    python ./tools/train.py \
      --device_target=$DEVICE_TRAGET \
      --config=$CONFIG_FILE
      --is_parallel=False > log.txt 2>&1 &
fi
