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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation_name,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
) 
SELECT 
    rp.p_name AS part_name,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.nation_name AS supplier_nation,
    cm.c_name AS customer_name,
    cm.c_mktsegment AS customer_segment,
    CASE 
        WHEN rp.brand_rank = 1 THEN 'Top Brand'
        ELSE 'Other Brand' 
    END AS brand_status,
    CASE 
        WHEN si.supp_rank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_status,
    CASE 
        WHEN cm.cust_rank = 1 THEN 'Top Customer'
        ELSE 'Other Customer'
    END AS customer_status
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    orders o ON ps.ps_partkey = o.o_orderkey
JOIN 
    CustomerMetrics cm ON o.o_custkey = cm.c_custkey
WHERE 
    rp.p_size BETWEEN 10 AND 20
ORDER BY 
    rp.p_retailprice DESC, si.s_acctbal DESC, cm.c_acctbal DESC;
