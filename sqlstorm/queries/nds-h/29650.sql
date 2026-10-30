WITH SupplierStringProcessing AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        TRIM(UPPER(REPLACE(s.s_comment, ' ', '_'))) AS processed_comment,
        LENGTH(s.s_address) AS address_length,
        CASE 
            WHEN s.s_acctbal < 1000 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High' 
        END AS acctbal_category
    FROM 
        supplier s
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ssp.s_suppkey,
    ssp.s_name,
    ssp.processed_comment,
    psd.supplier_count,
    psd.avg_supply_cost,
    od.total_revenue,
    od.distinct_parts,
    CONCAT('Supplier ', ssp.s_name, ' has ', psd.supplier_count, ' suppliers and total revenue of ', od.total_revenue) AS summary
FROM 
    SupplierStringProcessing ssp
JOIN 
    PartSupplierDetails psd ON ssp.s_suppkey = psd.ps_partkey
JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderkey LIMIT 1)
WHERE 
    ssp.acctbal_category = 'High'
ORDER BY 
    od.total_revenue DESC;
