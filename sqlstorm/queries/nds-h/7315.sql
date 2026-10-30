WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
), 
SupplierPartPrices AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS price_difference
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(DISTINCT lo.l_linenumber) AS item_count
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)

SELECT 
    ro.o_orderkey,
    ro.customer_name,
    ro.nation_name,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.order_rank,
    od.total_revenue,
    od.item_count,
    spp.supplier_name,
    spp.price_difference
FROM 
    RankedOrders ro
LEFT JOIN 
    OrderDetails od ON ro.o_orderkey = od.l_orderkey
LEFT JOIN 
    SupplierPartPrices spp ON spp.ps_supplycost < 10.00
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, 
    od.total_revenue DESC;
