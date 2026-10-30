WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT li.l_orderkey) AS order_count,
        AVG(li.l_extendedprice) AS avg_price
    FROM 
        part p
    LEFT JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    ps.total_supply_cost,
    ps.supplier_count,
    op.total_revenue,
    op.unique_customers,
    pp.order_count,
    pp.avg_price
FROM 
    SupplierStats ps
LEFT JOIN 
    OrderSummary op ON op.o_orderkey = ps.ps_partkey
LEFT JOIN 
    PartPopularity pp ON pp.p_partkey = ps.ps_partkey
WHERE 
    ps.total_supply_cost IS NOT NULL AND
    (pp.avg_price > 100 OR pp.order_count > 10)
ORDER BY 
    ps.total_supply_cost DESC, 
    op.total_revenue DESC;