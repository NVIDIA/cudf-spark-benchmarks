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
    WHERE 
        p.p_size > 10 AND 
        p.p_retailprice > 50.00
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000.00
),
OrderExpenses AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_expenditure
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000.00
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.nation_name,
    oe.total_expenditure
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrderExpenses oe ON sd.s_suppkey = oe.c_custkey
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, oe.total_expenditure DESC;
