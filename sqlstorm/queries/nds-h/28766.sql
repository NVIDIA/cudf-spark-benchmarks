WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS comment_length,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 0
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        LENGTH(o.o_comment) AS comment_length
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 1000.00
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    od.o_orderkey,
    od.o_totalprice,
    od.o_orderdate,
    sd.nation_name,
    sd.comment_length AS supplier_comment_length,
    pd.comment_length AS part_comment_length,
    od.comment_length AS order_comment_length
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    OrderDetails od ON li.l_orderkey = od.o_orderkey
WHERE 
    od.o_orderdate >= DATE '1997-01-01'
ORDER BY 
    sd.s_name, pd.p_name, od.o_orderdate DESC;