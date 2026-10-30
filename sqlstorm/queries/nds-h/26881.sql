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
    WHERE 
        p.p_comment LIKE '%fragile%'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_comment LIKE '%quality%'
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_orderkey) AS item_count,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_status_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_acctbal, o.o_orderdate, o.o_orderstatus
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.s_phone AS supplier_phone,
    od.c_name AS customer_name,
    od.total_value AS order_total,
    od.item_count AS order_item_count,
    od.o_orderdate AS order_date,
    od.o_orderstatus AS order_status,
    rp.brand_rank,
    od.order_status_rank
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    OrderDetails od ON ps.ps_partkey = od.o_orderkey
WHERE 
    rp.brand_rank <= 10
    AND od.order_status_rank <= 5
ORDER BY 
    rp.p_brand, od.total_value DESC;
