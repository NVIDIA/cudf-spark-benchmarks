WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        S.total_supply_cost,
        C.order_count,
        C.total_spent,
        RANK() OVER (PARTITION BY C.order_count ORDER BY C.total_spent DESC) AS sales_rank
    FROM 
        CustomerOrders C
    JOIN 
        SupplierStats S ON C.c_custkey = S.s_suppkey
)
SELECT 
    R.c_custkey,
    R.c_name,
    COALESCE(R.total_supply_cost, 0) AS supply_cost,
    R.order_count,
    COALESCE(R.total_spent, 0) AS total_spent,
    R.sales_rank
FROM 
    RankedSales R
WHERE 
    R.sales_rank <= 10 
UNION ALL
SELECT 
    NA.c_custkey,
    NA.c_name,
    0 AS supply_cost,
    NA.order_count,
    0 AS total_spent,
    NULL AS sales_rank
FROM 
    CustomerOrders NA
WHERE 
    NA.order_count = 0
ORDER BY 
    supply_cost DESC, total_spent DESC;
