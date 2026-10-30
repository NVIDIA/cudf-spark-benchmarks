
WITH part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        s.s_comment,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), customer_order_info AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), aggregated_data AS (
    SELECT 
        psi.p_partkey,
        psi.p_name,
        COUNT(DISTINCT coi.o_orderkey) AS order_count,
        SUM(psi.ps_availqty) AS total_availqty,
        AVG(psi.ps_supplycost) AS avg_supply_cost,
        SUM(coi.o_totalprice) AS total_order_value
    FROM 
        part_supplier_info psi
    LEFT JOIN 
        customer_order_info coi ON psi.supplier_name = coi.o_orderstatus
    GROUP BY 
        psi.p_partkey, psi.p_name
)
SELECT 
    ad.p_partkey,
    ad.p_name,
    ad.order_count,
    ad.total_availqty,
    ad.avg_supply_cost,
    ad.total_order_value,
    CASE 
        WHEN ad.order_count = 0 THEN 'No Orders' 
        ELSE 'Orders Placed' 
    END AS order_status
FROM 
    aggregated_data ad
WHERE 
    ad.total_order_value > 1000
ORDER BY 
    ad.total_order_value DESC, 
    ad.order_count DESC;
