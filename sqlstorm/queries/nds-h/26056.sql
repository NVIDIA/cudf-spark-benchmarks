WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS part_rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_name LIKE 'Supplier%'
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalMetrics AS (
    SELECT 
        rp.p_name,
        rp.p_mfgr,
        rp.p_retailprice,
        ss.s_name,
        ss.total_supply_cost,
        ss.order_count,
        CONCAT(rp.p_name, ' - ', ss.s_name) AS part_supplier_info
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierSales ss ON ss.total_supply_cost > 10000
    WHERE 
        rp.part_rank <= 10
)
SELECT 
    part_supplier_info, 
    AVG(total_supply_cost) AS avg_supply_cost, 
    SUM(order_count) AS total_orders
FROM 
    FinalMetrics
GROUP BY 
    part_supplier_info
ORDER BY 
    avg_supply_cost DESC;
