WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
OrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        l.l_partkey,
        p.p_mfgr,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, l.l_partkey, p.p_mfgr
),
SupplierDetails AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.o_totalprice,
        od.p_mfgr,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        OrderDetails od
    JOIN 
        partsupp ps ON od.l_partkey = ps.ps_partkey
    GROUP BY 
        od.o_orderkey, od.o_orderdate, od.o_totalprice, od.p_mfgr
)
SELECT 
    sd.o_orderkey,
    sd.o_orderdate,
    sd.o_totalprice,
    sd.p_mfgr,
    sd.supplier_count,
    sd.avg_supply_cost
FROM 
    SupplierDetails sd
ORDER BY 
    sd.o_orderdate DESC, sd.p_mfgr;
