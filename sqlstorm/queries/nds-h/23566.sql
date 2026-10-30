WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1997-01-01'
),
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        n.n_regionkey,
        r.r_name
    FROM 
        customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > l.l_commitdate
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cr.r_name, 
    COUNT(DISTINCT cr.c_custkey) AS num_customers,
    SUM(CASE 
        WHEN ro.order_rank <= 10 THEN ro.o_totalprice 
        ELSE 0 
    END) AS top_orders_total,
    AVG(fli.total_sales) AS avg_sales_per_order,
    MAX(fli.unique_parts) AS max_unique_parts
FROM 
    CustomerRegion cr
LEFT JOIN 
    RankedOrders ro ON cr.c_custkey = ro.o_orderkey
LEFT JOIN 
    FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
GROUP BY 
    cr.r_name
HAVING 
    COUNT(DISTINCT cr.c_custkey) > 5
ORDER BY 
    num_customers DESC NULLS LAST
LIMIT 
    20;