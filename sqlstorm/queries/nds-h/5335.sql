WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        n.n_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 10
),
SupplierPartSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderLineItem AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_suppkey) AS lineitem_supplier_count
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.c_name,
    hvo.n_name AS customer_nation,
    p.p_name,
    p.p_retailprice,
    sps.total_supply_cost AS part_supply_cost,
    oli.total_revenue AS order_revenue,
    sps.supplier_count AS part_supplier_count,
    oli.lineitem_supplier_count AS order_lineitem_supplier_count
FROM 
    HighValueOrders hvo
JOIN 
    lineitem li ON hvo.o_orderkey = li.l_orderkey 
JOIN 
    part p ON li.l_partkey = p.p_partkey
JOIN 
    SupplierPartSummary sps ON p.p_partkey = sps.ps_partkey
JOIN 
    OrderLineItem oli ON li.l_orderkey = oli.l_orderkey
WHERE 
    hvo.o_totalprice > 10000 AND sps.total_supply_cost > 5000
ORDER BY 
    hvo.o_orderdate, hvo.o_totalprice DESC;