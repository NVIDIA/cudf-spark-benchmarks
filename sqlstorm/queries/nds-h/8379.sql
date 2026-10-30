WITH SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS total_filled_orders,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS total_open_orders,
        AVG(o.o_totalprice) AS avg_order_total,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
RegionNationStats AS (
    SELECT 
        n.n_regionkey,
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    sos.s_name,
    sos.total_filled_orders,
    sos.total_open_orders,
    sos.avg_order_total,
    rns.region_name,
    rns.total_nations,
    rns.total_supplier_balance
FROM 
    SupplierOrderStats sos
JOIN 
    RegionNationStats rns ON sos.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_acctbal > 5000
    )
ORDER BY 
    sos.avg_order_total DESC, 
    rns.total_nations ASC;
