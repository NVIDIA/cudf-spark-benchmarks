WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 5
), PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), AggregatedSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_tax) AS total_tax,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        TopOrders t ON l.l_orderkey = t.o_orderkey
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_retailprice,
    p.p_comment,
    psi.total_avail_qty,
    psi.avg_supply_cost,
    asi.total_sales,
    asi.total_tax,
    asi.order_count
FROM 
    part p
JOIN 
    PartSupplierInfo psi ON p.p_partkey = psi.ps_partkey
JOIN 
    AggregatedSales asi ON p.p_partkey = asi.l_partkey
WHERE 
    p.p_size > 10 AND 
    psi.total_avail_qty > 0
ORDER BY 
    asi.total_sales DESC
LIMIT 100;
