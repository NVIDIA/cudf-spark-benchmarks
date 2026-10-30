WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
),
SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
        AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalReport AS (
    SELECT 
        hvo.o_orderkey,
        hvo.o_orderdate,
        hvo.o_totalprice,
        COALESCE(so.total_supply_cost, 0) AS supplier_cost,
        hvo.line_count
    FROM 
        HighValueOrders hvo
    LEFT JOIN 
        SupplierOrders so ON hvo.o_orderkey = so.s_suppkey
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.supplier_cost,
    fr.line_count,
    CASE 
        WHEN fr.supplier_cost IS NULL THEN 'No Supplier' 
        ELSE 'Has Supplier' 
    END AS supplier_status
FROM 
    FinalReport fr
WHERE 
    fr.o_totalprice - fr.supplier_cost > 5000
ORDER BY 
    fr.o_totalprice DESC;