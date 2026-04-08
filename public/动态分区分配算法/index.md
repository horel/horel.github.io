# 动态分区分配算法


+ 首次适应算法FF
+ 循环首次适应算法NF
+ 最佳适应算法BF
+ 最差适应算法WF
```cpp
#include <malloc.h>
#include <stdio.h>
#include <stdlib.h>

#define PROCESS_NAME_LEN 32   //进程名字长度
#define MIN_SLICE 10          //最小碎片大小
#define DEFAULT_MEM_SIZE 1024 // 默认的内存大小
#define DEFAULT_MEM_START 0   //起始地址

#define MA_FF 1 //首次适应算法
#define MA_BF 2 //最佳适应算法
#define MA_WF 3 //最坏适应算法
#define MA_NF 4 //临近适应算法（循环首次适应算法）

//空闲分区的结构体
typedef struct free_block_type {
    int size;
    int start_addr;
    struct free_block_type *next;
} free_block_type;
/*指向内存中空闲块链表的首指针*/
free_block_type *free_block;

//已分配分区的结构体
typedef struct allocated_block {
    int pid;
    int size;
    int start_addr;
    char process_name[PROCESS_NAME_LEN];
    struct allocated_block *next;
} allocated_block;
//进程分配内存块链表的首指针
struct allocated_block *allocated_block_head = NULL;

int mem_size = DEFAULT_MEM_SIZE;    // 内存大小
int ma_algorithm = MA_FF;   // 动态分区分配算法
static int pid = 0;     //  进程号
int flag = 0;   // 判断内存是否被修改标志

//函数声明
void display_menu();    // 显示主菜单
int set_mem_size();     // 设置内存大小
void set_algorithm();   // 选择当前算法
void rearrange(int algorithm);  // 为每一个进程分配完内存以后重新按已选择的算法再次排序
int new_process();      // 创建一个新的进程
int allocate_mem(struct allocated_block *ab);   // 内存分配
void kill_process();    // 杀死进程
int free_mem(struct allocated_block *ab);       // 释放杀死进程的内存块
int dispose(struct allocated_block *free_ab);   // 销毁杀死进程的结点
int display_mem_usage();    // 显示内存使用情况
allocated_block *find_process(int pid);         // 找到要杀死的进程的标号
void rearrange_FF();    // 首次适应算法
void rearrange_BF();    // 最佳适应算法
void rearrange_WF();    // 最坏适应算法
void rearrange_NF();    // 临近适应算法（循环首次适应算法）

//初始化空闲分区
free_block_type *init_free_block(int mem_size) {
    free_block_type *fb;
    fb = (free_block_type *)malloc(sizeof(free_block_type));
    if (fb == NULL) {
        printf("No mem\n");
        return NULL;
    }
    fb->size = mem_size;
    fb->start_addr = DEFAULT_MEM_START;
    fb->next = NULL;
    return fb;
}

//显示主菜单
void display_menu() {
    printf("\n");
    printf("1 - Set memory size (default=%d)\n", DEFAULT_MEM_SIZE);
    printf("2 - Select memory allocation algorithm\n");
    printf("3 - New process \n");
    printf("4 - Terminate a process \n");
    printf("5 - Display memory usage \n");
    printf("0 - Exit\n");
}

/*设置内存大小*/
int set_mem_size() {
    int size;
    if (flag != 0) { /*flag标志防止内存被再次设置*/
        printf("Cannot set memory size again\n");
        return 0;
    }
    printf("Total memory size =");
    scanf("%d", &size);
    if (size > 0) {
        mem_size = size;
        free_block->size = mem_size; /*设置初始大小为 1024*/
    }
    flag = 1;
    return 1;
}
/*选择当前算法*/
void set_algorithm() {
    int algorithm;
    printf("\t1 - First Fit\n");
    printf("\t2 - Best Fit \n");
    printf("\t3 - Worst Fit \n");
    printf("\t4 - Next Fit\n");
    printf("Please input your choice : ");
    scanf("%d", &algorithm);
    if (algorithm >= 1 && algorithm <= 4)
        ma_algorithm = algorithm;

    rearrange(ma_algorithm);
}

/*为每一个进程分配完内存以后重新按已选择的算法再次排序*/
void rearrange(int algorithm) {
    switch (algorithm) {
    case MA_FF:
        rearrange_FF();
        break;
    case MA_BF:
        rearrange_BF();
        break;
    case MA_WF:
        rearrange_WF();
        break;
    case MA_NF:
        rearrange_NF();
        break;
    }
}

/*首次适应算法，按地址的大小由小到大排序*/
void rearrange_FF() {
    free_block_type *temp, *p = NULL;
    free_block_type *head = NULL;
    int current_min_addr;

    if (free_block) {
        temp = free_block;
        current_min_addr = free_block->start_addr;
        while (temp->next != NULL) {
            if (temp->next->start_addr < current_min_addr) {
                current_min_addr = temp->next->start_addr;
                p = temp;
            }
            temp = temp->next;
        }
        if (p != NULL) {
            temp = p->next;
            p->next = p->next->next;
            temp->next = free_block;
            free_block = temp;
        }
        head = free_block;
        p = head;
        temp = head->next;
        while (head->next != NULL) {
            current_min_addr = head->next->start_addr;
            while (temp->next != NULL) {
                if (temp->next->start_addr < current_min_addr) {
                    current_min_addr = temp->next->start_addr;
                    p = temp;
                }
                temp = temp->next;
            }
            if (p->next != head->next) {
                temp = p->next;
                p->next = p->next->next;
                temp->next = head->next;
                head->next = temp;
            }
            head = head->next;
            temp = head->next;
            p = head;
        }
    }
    return;
}

/*最佳适应算法，按内存块的大小由小到大排序*/
void rearrange_BF() {
    free_block_type *temp, *p = NULL;
    free_block_type *head = NULL;
    int current_min_size = free_block->size;

    temp = free_block;
    while (temp->next != NULL) {
        if (temp->next->size < current_min_size) {
            current_min_size = temp->next->size;
            p = temp;
        }
        temp = temp->next;
    }
    if (p != NULL) {
        temp = p->next;
        p->next = p->next->next;
        temp->next = free_block;
        free_block = temp;
    }
    head = free_block;
    p = head;
    temp = head->next;
    while (head->next != NULL) {
        current_min_size = head->next->size;
        while (temp->next != NULL) {
            if (temp->next->size < current_min_size) {
                current_min_size = temp->next->size;
                p = temp;
            }
            temp = temp->next;
        }
        if (p->next != head->next) {
            temp = p;
            p->next = p->next->next;
            temp->next = head->next;
            head->next = temp;
        }
        head = head->next;
        temp = head->next;
        p = head;
    }
}

/*最坏适应算法，按地址块的大小从大到小排序*/
void rearrange_WF() {
    free_block_type *temp, *p = NULL;
    free_block_type *head = NULL;
    int current_max_size = free_block->size;
    temp = free_block;
    while (temp->next != NULL) {
        if (temp->next->size > current_max_size) {
            current_max_size = temp->next->size;
            p = temp;
        }
        temp = temp->next;
    }
    if (p != NULL) {
        temp = p;
        p->next = p->next->next;
        temp->next = free_block;
        free_block = temp;
    }
    head = free_block;
    p = head;
    temp = head->next;
    while (head->next != NULL) {
        current_max_size = head->next->size;
        while (temp->next != NULL) {
            if (temp->next->size > current_max_size) {
                current_max_size = temp->next->size;
                p = temp;
            }
            temp = temp->next;
        }
        if (p->next != head->next) {
            temp = p->next;
            p->next = p->next->next;
            temp->next = head->next;
            head->next = temp;
        }
        head = head->next;
        temp = head->next;
        p = head;
    }
    return;
}

// 临近适应算法（循环首次适应算法）
struct free_block_type *NF_tmp = NULL;
void rearrange_NF(){
    free_block_type *temp, *p = NULL;
    free_block_type *head = NULL;
    int current_min_addr;

    if (free_block) {
        temp = free_block;
        current_min_addr = free_block->start_addr;
        // 找到最小的地址
        while (temp->next != NULL) {
            if (temp->next->start_addr < current_min_addr) {
                current_min_addr = temp->next->start_addr;
                p = temp;
            }
            temp = temp->next;
        } // 让最小的地址成为空闲内存链表头
        if (p != NULL) {
            temp = p->next;
            p->next = p->next->next;
            temp->next = free_block;
            free_block = temp;
        }
        head = free_block;
        p = head;
        temp = head->next;
        while (head->next != NULL) {    // 从头开始向后遍历，把最小的地址的内存逐次接起来
            current_min_addr = head->next->start_addr;
            while (temp->next != NULL) {    // 找到剩余最小的地址的内存
                if (temp->next->start_addr < current_min_addr) {
                    current_min_addr = temp->next->start_addr;
                    p = temp;
                }
                temp = temp->next;
            }
            if (p->next != head->next) {    // 把找到的最小的接起来
                temp = p->next;
                p->next = p->next->next;
                temp->next = head->next;
                head->next = temp;      // 接上新的较小的头
            } 
            head = head->next;  // 继续向后遍历
            temp = head->next;
            p = head;
        }
    }
    return;
}


//创建一个新的进程
int new_process() {
    struct allocated_block *ab;
    int size;
    int ret;
    ab = (struct allocated_block *)malloc(sizeof(struct allocated_block));
    if (!ab)
        exit(-5);
    ab->next = NULL;
    pid++;
    sprintf(ab->process_name, "PROCESS-%02d", pid);
    ab->pid = pid;
    printf("Memory for %s:", ab->process_name);
    printf("Please input you want to allocate process' size : ");
    scanf("%d", &size);
    if (size > 0) {

        ab->size = size;
    }
    ret = allocate_mem(ab);
    if ((ret == 1) && (allocated_block_head == NULL)) {
        allocated_block_head = ab;
        return 1;
    }

    else if (ret == 1) {
        ab->next = allocated_block_head;
        allocated_block_head = ab;
        return 2;
    } else if (ret == -1) {
        printf("Allocation fail\n");
        pid--;
        free(ab);
        return -1;
    }
    return 3;
}

// NF专属内存分配
int allocate_mem_NF(struct allocated_block *ab, int ab_size) {
    struct free_block_type *fbt, *pre, *temp, *work, *F = NULL;
    int request_size = ab_size;
    // 与上一次位置有关
    if (NF_tmp == free_block || NF_tmp == NULL) { // 从头或者首次分配
        F = NULL;
        NF_tmp = free_block;
    } else
        F = NF_tmp;     // F记录保存上次位置，作为循环判断条件
    fbt = NF_tmp;
    pre = fbt;
    do {
        if (F != NULL && fbt == NULL)
            fbt = free_block;
        if (fbt->size >= request_size) {
            NF_tmp = fbt;
            if (fbt->size - request_size >= MIN_SLICE) {    /*分配后空闲空间足够大，则分割*/
                // mem_size -= request_size;
                fbt->size -= request_size;
                ab->start_addr = fbt->start_addr;
                fbt->start_addr += request_size;
                NF_tmp = fbt;   // 重新记录分配位置
            } else if ((fbt->size - request_size) < MIN_SLICE) {                /*分割后空闲区成为小碎片，一起分配*/
                // mem_size -= fbt->size;
                if (pre == free_block)
                    free_block = fbt->next;
                else if (pre == fbt)
                    for (pre = free_block; pre->next != NULL; pre = pre->next)
                        if (pre->next == fbt)
                            break;
                pre->next = fbt->next;
                NF_tmp = fbt->next;     // 重新记录分配位置
                ab->start_addr = fbt->start_addr;
                ab->size = fbt->size;
                free(fbt);
            } else {
                temp = free_block;
                while (temp != NULL) {
                    work = temp->next;

                    if (work != NULL) {     /*如果当前空闲区与后面的空闲区相连，则合并*/
                        if (temp->start_addr + temp->size == work->start_addr) {
                            temp->size += work->size;
                            temp->next = work->next;
                            if (NF_tmp == work)
                                NF_tmp = temp;
                            free(work);
                            continue;
                        }
                    }

                    temp = temp->next;
                }
                rearrange(ma_algorithm); /*重新按当前的算法排列空闲区*/
            }
            return 1;
        }
        pre = fbt;
        fbt = fbt->next;
    } while (fbt != F);     // 判断fbt是否循环完一圈
    return -1;
}

//内存分配
int allocate_mem(struct allocated_block *ab) {
    if(ma_algorithm == MA_NF) {
        return allocate_mem_NF(ab, ab->size);
    }
    free_block_type *fbt, *pre;
    free_block_type *temp, *p, *p1;
    allocated_block *q;
    int request_size = ab->size;
    int sum = 0;
    int max;
    fbt = pre = free_block;
    // 若有空闲内存
    if (fbt) {
        if (ma_algorithm == MA_WF) {
            // 若是最坏适应算法且最大的空闲内存也不够
            if (fbt == NULL || fbt->size < request_size)
                return -1;
        } else {    // 若不是WF则是由小到大排列，遍历空闲内存寻找需要的大小
            while (fbt != NULL && fbt->size < request_size) {
                pre = fbt;
                fbt = fbt->next;
            }
        } // 遍历完仍旧找不到
        if (fbt == NULL || fbt->size < request_size) {
            if (free_block->next != NULL) {     // 将剩余内存空间相加看是否足够
                sum = free_block->size;
                temp = free_block->next;
                while (temp != NULL) {
                    sum += temp->size;
                    if (sum >= request_size)
                        break;
                    temp = temp->next;
                }
                if (temp == NULL) // 还不够，退出
                    return -1;
                else {  // 足够
                    pre = free_block;
                    max = free_block->start_addr;
                    fbt = free_block;
                    while (temp->next != pre) {     // 找到这些块的最大地址
                        if (max < pre->start_addr) {
                            max = pre->start_addr;
                            fbt = pre;
                        }
                        pre = pre->next;
                    }
                    pre = free_block;

                    while (pre != temp->next) {
                        q = allocated_block_head;
                        p = free_block;

                        while (q != NULL) {     // 向前推 
                            if (q->start_addr > pre->start_addr)
                                q->start_addr = q->start_addr - pre->size;
                            q = q->next;
                        }
                        while (p != NULL) {
                            if (p->start_addr > pre->start_addr)
                                p->start_addr = p->start_addr - pre->size;
                            p = p->next;
                        }

                        pre = pre->next;
                    }

                    pre = free_block;
                    while (pre != temp->next) {

                        p1 = pre->next;
                        if (pre == fbt)     // 最大块
                            break;
                        free(pre);
                        pre = p1;
                    }
                    q = allocated_block_head;
                    free_block = fbt;
                    free_block->start_addr = q->start_addr + q->size;

                    free_block->size = sum;
                    free_block->next = temp->next;
                    if (free_block->size - request_size < MIN_SLICE) {  // 分割后太小就一起分割 
                        ab->size = free_block->size;
                        ab->start_addr = free_block->start_addr;
                        pre = free_block;
                        free_block = free_block->next;
                        free(pre);
                    } else {    // 分割内存
                        ab->start_addr = free_block->start_addr;
                        free_block->start_addr =
                            free_block->start_addr + request_size;
                        free_block->size = free_block->size - request_size;
                    }
                }
            } else   // 剩余空间相加仍旧不够
                return -1;
        } else {    // 遍历空闲内存找到了足够大的
            if (fbt->size - request_size < MIN_SLICE) {     // 分割后太小就一起分割 
                ab->size = fbt->size;
                ab->start_addr = fbt->start_addr;
                if (pre->next == free_block) {
                    free_block = fbt->next;
                } else {
                    pre->next = fbt->next;
                }
                free_block = fbt->next;
                free(fbt);
            } else {    // 分割内存
                ab->start_addr = fbt->start_addr;
                fbt->start_addr = fbt->start_addr + request_size;
                fbt->size = fbt->size - request_size;
            }
        }
        rearrange(ma_algorithm);
        return 1;
    } else {    // 无空闲内存
        printf("Free Memory already has been allocated over: ");
        return -1;
    }
}

//选择杀死一个进程
void kill_process() {
    struct allocated_block *ab;
    int pid;
    printf("Kill Process, pid=");
    scanf("%d", &pid);
    ab = find_process(pid);
    if (ab != NULL) {
        free_mem(ab);
        dispose(ab);
    }
}

//找到要杀死的进程的标号
allocated_block *find_process(int pid) {
    allocated_block *abb;
    abb = allocated_block_head;
    if (abb->pid == pid) {
        return abb;
    }
    abb = allocated_block_head->next;
    while (abb->next != NULL) {
        if (abb->pid == pid)
            return abb;
        abb = abb->next;
    }
    return abb;
}

//释放杀死进程的内存块
int free_mem(struct allocated_block *ab) {
    int algorithm = ma_algorithm;
    struct free_block_type *fbt, *pre;
    fbt = (struct free_block_type *)malloc(sizeof(struct free_block_type));
    pre = (struct free_block_type *)malloc(sizeof(struct free_block_type));
    if (!fbt)
        return -1;

    fbt->start_addr = ab->start_addr;
    fbt->size = ab->size;
    fbt->next = free_block;
    free_block = fbt;
    rearrange_FF();
    pre->next = free_block;
    pre->size = 0;
    while (pre->next && (pre->next->start_addr != fbt->start_addr))
        pre = pre->next;
    if (pre->size != 0 && fbt->next != NULL) {
        if (((pre->start_addr + pre->size) == fbt->start_addr) &&
            ((fbt->start_addr + fbt->size) == fbt->next->start_addr)) {
            pre->size = pre->size + fbt->size + fbt->next->size;
            pre->next = fbt->next->next;
            free(fbt->next);
            free(fbt);
        } else if ((pre->start_addr + pre->size) == fbt->start_addr) {
            pre->size = pre->size + fbt->size;
            pre->next = fbt->next;
            free(fbt);
        } else if (fbt->start_addr + fbt->size == fbt->next->start_addr) {
            fbt->size = fbt->size + fbt->next->size;
            fbt->next = fbt->next->next;
            free(fbt->next);
        }
    } else if ((pre->size == 0) && fbt->next) {
        if ((fbt->start_addr + fbt->size) == fbt->next->start_addr) {
            fbt->size = fbt->size + fbt->next->size;
            fbt->next = fbt->next->next;
            free_block = fbt;
            free(fbt->next);
        }
    } else if (fbt->next == NULL) {
        if ((pre->start_addr + pre->size) == fbt->start_addr) {
            pre->size = pre->size + fbt->size;
            pre->next = fbt->next;
            free(fbt);
        }
    }
    rearrange(algorithm);

    return 1;
}

//销毁杀死进程的结点
int dispose(struct allocated_block *free_ab) {
    struct allocated_block *pre, *ab;

    if (free_ab == allocated_block_head) {
        allocated_block_head = allocated_block_head->next;
        free(free_ab);
        return 1;
    }
    pre = allocated_block_head;
    ab = allocated_block_head->next;
    while (ab != free_ab) {
        pre = ab;
        ab = ab->next;
    }
    pre->next = ab->next;
    free(ab);
    return 2;
}

//显示内存使用情况
int display_mem_usage() {
    struct free_block_type *fbt = free_block;
    struct allocated_block *ab = allocated_block_head;
    printf("----------------------------------------------------------\n");

    if (fbt == NULL) {
        printf("Free Memory already used over !\n");
    }
    printf("----------------------------------------------------------\n");

    if (fbt) {
        printf("Free Memory:\n");
        printf("%20s %20s\n", " start_addr", " size");
        while (fbt != NULL) {
            printf("%20d %20d\n", fbt->start_addr, fbt->size);
            fbt = fbt->next;
        }
    }

    printf("\nUsed Memory:\n");
    printf("%10s %20s %15s %10s\n", "PID", "ProcessName", "start_addr",
           " size");
    while (ab != NULL) {
        printf("%10d %20s %15d %10d\n", ab->pid, ab->process_name,
               ab->start_addr, ab->size);
        ab = ab->next;
    }
    printf("----------------------------------------------------------\n");
    return 0;
}

//退出，销毁所有链表
void do_exit() {
    free_block_type *temp;
    allocated_block *temp1;

    temp = free_block->next;
    while (temp != NULL) {
        free_block->next = temp->next;
        free(temp);
        temp = free_block->next;
    }
    free(free_block);

    if(!allocated_block_head)
        return;
    temp1 = allocated_block_head->next;
    while (temp1 != NULL) {
        allocated_block_head->next = temp1->next;
        free(temp1);
        temp1 = allocated_block_head->next;
    }
    free(allocated_block_head->next);
}
//主函数
int main() {
    char choice;
    pid = 0;
    free_block = init_free_block(mem_size);
    while (1) {
        display_menu();
        fflush(stdin);

        choice = getchar();
        switch (choice) {
        case '1':
            set_mem_size();
            break;
        case '2':
            set_algorithm();
            flag = 1;
            break;
        case '3':
            new_process();
            flag = 1;
            break;
        case '4':
            kill_process();
            flag = 1;
            break;
        case '5':
            display_mem_usage();
            flag = 1;
            break;
        case '0':
            do_exit();
            exit(0);
        default:
            break;
        }
    }
    return 0;
}
```


