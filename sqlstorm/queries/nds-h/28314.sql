WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_type, 
        p.p_brand, 
        p.p_mfgr,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
),
TopSuppliers AS (
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
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrdersWithParts AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_orderkey, 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_retailprice, 
        ts.s_name AS supplier_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        RankedParts rp ON l.l_partkey = rp.p_partkey
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    WHERE 
        rp.rank <= 5
)
SELECT 
    owp.o_orderkey, 
    owp.o_orderdate, 
    owp.p_name, 
    owp.supplier_name, 
    SUM(owp.p_retailprice) AS total_price
FROM 
    OrdersWithParts owp
GROUP BY 
    owp.o_orderkey, 
    owp.o_orderdate, 
    owp.p_name, 
    owp.supplier_name
ORDER BY 
    total_price DESC;
