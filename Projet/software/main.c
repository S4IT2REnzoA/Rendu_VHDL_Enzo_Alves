#include <stdint.h>

#define START_SL   (*(volatile uint32_t*)0x04003040)
#define START_ROT  (*(volatile uint32_t*)0x04003030)
#define DIR_ROT    (*(volatile uint32_t*)0x04003020)
#define FIN_SL     (*(volatile uint32_t*)0x04003010)
#define FIN_ROT    (*(volatile uint32_t*)0x04003000)

typedef enum {
    ETAT_SUIVI,
    ETAT_ROTATION
} etat_t;

void delay(volatile int count)
{
    while (count--);
}

int main()
{
    etat_t etat = ETAT_SUIVI;

    DIR_ROT = 1;

    while (1)
    {
        switch (etat)
        {
            case ETAT_SUIVI:
                START_SL  = 1;
                START_ROT = 0;

                if (FIN_SL == 1)
                {
                	delay(750000);
                    etat = ETAT_ROTATION;
                }
                break;

            case ETAT_ROTATION:
                START_SL  = 0;
                START_ROT = 1;

                if (FIN_ROT == 1)
                {
                	delay(750000);
                    etat = ETAT_SUIVI;
                }
                break;
        }
        delay(500);
    }

    return 0;
}