
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    COALESCE(SUM(DISTINCT li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    ss.total_supply_cost,
    cs.avg_order_value,
    RANK() OVER (ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS customer_rank
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierStats ss ON li.l_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrderSummary cs ON c.c_custkey = cs.c_custkey
WHERE 
    c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
GROUP BY 
    c.c_name, ss.total_supply_cost, cs.avg_order_value
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
