
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND
        s.s_acctbal > (
            SELECT 
                AVG(s2.s_acctbal) 
            FROM 
                supplier s2 
            WHERE 
                s2.s_nationkey = s.s_nationkey
        )
), PartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), HighDemandOrders AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1998-10-01' - INTERVAL '30 days' 
    GROUP BY 
        l.l_orderkey 
    HAVING 
        SUM(l.l_quantity) > 100
), CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_acctbal > (
            SELECT 
                AVG(c2.c_acctbal) 
            FROM 
                customer c2 
            WHERE 
                c2.c_mktsegment = c.c_mktsegment
        )
), SupplierNation AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    RS.s_name AS r_name,
    pt.p_name,
    COALESCE(HA.total_quantity, 0) AS total_quantity,
    PA.total_avail_qty,
    PA.avg_supply_cost,
    CN.c_name,
    SNS.supplier_count,
    CASE 
        WHEN HA.total_quantity > 0 THEN 'High Demand'
        ELSE 'Check Stock'
    END AS order_status
FROM 
    RankedSuppliers AS RS
JOIN 
    PartAvailability AS PA ON PA.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost < 50
    )
LEFT JOIN 
    HighDemandOrders AS HA ON HA.l_orderkey = RS.s_suppkey
JOIN 
    customer AS CN ON CN.c_custkey = RS.s_suppkey
JOIN 
    SupplierNation AS SNS ON SNS.n_name = RS.s_name
JOIN 
    part AS pt ON pt.p_partkey = PA.ps_partkey
WHERE 
    RS.rnk = 1
ORDER BY 
    total_quantity DESC, 
    SNS.supplier_count DESC;
