WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND
        o.o_orderstatus IN ('O', 'F')
),
AggregatedSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000.00
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)

SELECT 
    n.n_name,
    r.r_name,
    COALESCE(SUM(a.total_supply_value), 0) AS total_supply_value,
    COALESCE(SUM(cos.total_orders), 0) AS total_orders,
    COALESCE(AVG(cos.avg_order_value), 0) AS avg_order_value
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    AggregatedSuppliers a ON n.n_nationkey = a.ps_suppkey
LEFT JOIN 
    CustomerOrderSummary cos ON n.n_nationkey = cos.c_custkey
WHERE 
    r.r_name LIKE 'Europe%' AND 
    n.n_comment IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supply_value DESC, total_orders DESC
LIMIT 10;