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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        c.c_name,
        c.c_mktsegment,
        c.c_comment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, c.c_name, c.c_mktsegment, c.c_comment
),
FinalBenchmark AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        COUNT(DISTINCT co.o_orderkey) AS order_count,
        SUM(co.order_value) AS total_order_value,
        COUNT(DISTINCT fs.s_suppkey) AS supplier_count
    FROM 
        RankedParts rp
    LEFT JOIN 
        CustomerOrders co ON rp.p_partkey = co.o_orderkey
    LEFT JOIN 
        FilteredSuppliers fs ON rp.p_brand = fs.s_name 
    WHERE 
        rp.rank <= 10
    GROUP BY 
        rp.p_name, rp.p_brand
)
SELECT 
    p_name,
    p_brand,
    order_count,
    total_order_value,
    supplier_count
FROM 
    FinalBenchmark
ORDER BY 
    total_order_value DESC;
