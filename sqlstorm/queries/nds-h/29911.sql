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
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
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
        s.s_comment,
        SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice,
        CONCAT(c.c_name, ' - ', CONCAT(l.l_quantity, ' items')) AS customer_order_info
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    rp.p_name, 
    fs.s_name, 
    od.customer_order_info, 
    od.o_totalprice, 
    od.o_orderdate
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    OrderDetails od ON rp.p_partkey = od.l_partkey
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.p_retailprice DESC, 
    od.o_totalprice DESC;
