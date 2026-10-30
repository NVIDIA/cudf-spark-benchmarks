
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.nation_name,
        hvp.total_revenue,
        si.supplier_value
    FROM 
        RankedOrders ro
    LEFT JOIN 
        HighValueParts hvp ON ro.o_orderkey = hvp.l_orderkey
    LEFT JOIN 
        SupplierInfo si ON hvp.l_partkey = si.ps_partkey
    WHERE 
        ro.price_rank <= 5
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.c_name,
    fr.nation_name,
    fr.total_revenue,
    fr.supplier_value
FROM 
    FinalReport fr
ORDER BY 
    fr.o_orderdate DESC,
    fr.total_revenue DESC
LIMIT 100;
