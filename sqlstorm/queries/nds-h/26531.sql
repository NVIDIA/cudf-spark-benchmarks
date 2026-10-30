WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierLink AS (
    SELECT 
        pp.ps_partkey,
        pp.ps_suppkey,
        sp.s_name AS supplier_name,
        pp.ps_availqty,
        pp.ps_supplycost,
        pp.ps_comment
    FROM 
        partsupp pp
    JOIN 
        SupplierDetails sp ON pp.ps_suppkey = sp.s_suppkey
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_type,
    rp.p_container,
    rp.p_retailprice,
    cs.c_name AS top_customer,
    cs.order_count,
    cs.total_spent,
    COUNT(DISTINCT ps.supplier_name) AS unique_suppliers
FROM 
    RankedParts rp
LEFT JOIN 
    PartSupplierLink ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerSummary cs ON cs.order_count > 5
WHERE 
    rp.rn = 1
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_mfgr, rp.p_type, rp.p_container, rp.p_retailprice, cs.c_name, cs.order_count, cs.total_spent
ORDER BY 
    rp.p_retailprice DESC;
