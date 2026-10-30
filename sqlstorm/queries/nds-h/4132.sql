
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    cs.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    cs.order_count,
    ps.total_available,
    ps.total_supply_cost,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value Customer'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment,
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice
FROM 
    CustomerSummary cs
FULL OUTER JOIN 
    PartSupplier ps ON cs.c_custkey = ps.p_partkey
RIGHT JOIN 
    RankedOrders r ON cs.order_count IS NOT NULL AND cs.c_custkey = r.o_orderkey
WHERE 
    ps.total_available IS NOT NULL OR cs.total_spent IS NOT NULL
ORDER BY 
    total_spent DESC, r.o_orderdate ASC;
