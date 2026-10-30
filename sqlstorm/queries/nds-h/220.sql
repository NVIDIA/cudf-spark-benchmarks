
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SI.supplier_count, 0) AS supplier_count,
    COALESCE(SI.total_supply_value, 0.00) AS total_supply_value,
    RO.c_name AS highest_spending_customer,
    RO.o_totalprice AS highest_spending_total
FROM 
    part p
LEFT JOIN 
    SupplierInfo SI ON p.p_partkey = SI.ps_partkey
LEFT JOIN 
    RankedOrders RO ON RO.o_orderkey IN (
        SELECT 
            l.l_orderkey
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = p.p_partkey
    )
WHERE 
    p.p_container LIKE 'SMALL BOX%' 
    AND p.p_retailprice BETWEEN 100.00 AND 500.00
GROUP BY 
    p.p_partkey,
    p.p_name,
    SI.supplier_count,
    SI.total_supply_value,
    RO.c_name,
    RO.o_totalprice
ORDER BY 
    p.p_partkey, highest_spending_total DESC
LIMIT 10;
