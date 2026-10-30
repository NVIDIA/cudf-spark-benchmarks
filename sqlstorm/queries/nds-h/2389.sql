WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
CustomerTotals AS (
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
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name,
    COALESCE(ct.total_spent, 0) AS total_spent,
    COALESCE(ct.order_count, 0) AS order_count,
    sp.num_parts,
    sp.total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ct.total_spent, 0) DESC) AS customer_rank
FROM 
    CustomerTotals ct
FULL OUTER JOIN 
    customer c ON ct.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierParts sp ON sp.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey
        WHERE 
            p.p_size > 10
        ORDER BY 
            ps.ps_supplycost DESC
        LIMIT 1
    )
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    customer_rank;
