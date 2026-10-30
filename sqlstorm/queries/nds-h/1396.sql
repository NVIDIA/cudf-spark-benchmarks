WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    part_details.p_name,
    part_details.p_brand,
    part_details.p_retailprice,
    supplier_info.s_name,
    supplier_info.nation_name,
    order_data.total_revenue,
    order_data.item_count
FROM 
    RankedParts part_details
LEFT JOIN 
    partsupp ps ON part_details.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails supplier_info ON ps.ps_suppkey = supplier_info.s_suppkey
LEFT JOIN 
    OrderInfo order_data ON supplier_info.s_suppkey = order_data.o_custkey
WHERE 
    part_details.rank <= 5
    AND (supplier_info.s_acctbal IS NULL OR supplier_info.s_acctbal > 100000)
ORDER BY 
    part_details.p_brand, order_data.total_revenue DESC;
