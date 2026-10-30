
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_discount) AS total_discounted
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        ss.total_available_qty,
        ss.avg_acctbal,
        ss.unique_parts_supplied,
        ROW_NUMBER() OVER (PARTITION BY (CASE WHEN ss.avg_acctbal > 10000 THEN 'High' ELSE 'Low' END) ORDER BY ss.total_available_qty DESC) AS supplier_rank
    FROM 
        SupplierSummary ss
    INNER JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
ConfirmedOrders AS (
    SELECT 
        od.o_orderkey, 
        od.total_lineitems,
        od.total_revenue,
        od.total_discounted,
        ROW_NUMBER() OVER (ORDER BY od.total_revenue DESC) AS order_rank
    FROM 
        OrderDetails od
    WHERE 
        od.total_lineitems IS NOT NULL OR od.total_revenue IS NOT NULL
)
SELECT 
    r.s_name, 
    r.total_available_qty, 
    r.avg_acctbal, 
    oo.total_lineitems, 
    oo.total_revenue, 
    oo.total_discounted
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    ConfirmedOrders oo ON r.supplier_rank = oo.order_rank
WHERE 
    (r.total_available_qty IS NULL OR r.total_available_qty > 100)
    AND COALESCE(oo.total_revenue, 0) > (SELECT AVG(total_revenue) FROM ConfirmedOrders)
ORDER BY 
    COALESCE(r.avg_acctbal, 0) DESC, 
    COALESCE(oo.total_revenue, 0) DESC;
