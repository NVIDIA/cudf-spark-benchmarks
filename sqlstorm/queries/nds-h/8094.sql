WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), TopCustomers AS (
    SELECT 
        ro.c_name,
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
), CustomerSales AS (
    SELECT 
        c.c_nationkey,
        SUM(tc.o_totalprice) AS total_spent
    FROM 
        TopCustomers tc
    JOIN 
        customer c ON tc.c_name = c.c_name
    GROUP BY 
        c.c_nationkey
), RegionalPerformance AS (
    SELECT 
        r.r_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        CustomerSales cs ON n.n_nationkey = cs.c_nationkey
)
SELECT 
    rp.r_name,
    rp.total_spent,
    rp.rank
FROM 
    RegionalPerformance rp
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.total_spent DESC;