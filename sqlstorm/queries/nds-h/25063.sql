WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_address) AS address_length,
        UPPER(s.s_comment) AS upper_comment,
        LOWER(s.s_comment) AS lower_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_brand, ' - ', p.p_name) AS full_description,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, c.c_name
)
SELECT 
    sd.s_name,
    sd.nation_name,
    pd.p_type,
    od.o_orderdate,
    pd.full_description,
    od.total_extended_price,
    sd.upper_comment,
    sd.lower_comment,
    sd.name_length,
    sd.address_length,
    od.line_count
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderDetails od ON od.o_orderkey = ps.ps_partkey
WHERE 
    sd.name_length > 10 AND 
    pd.p_size < 100 AND 
    od.o_totalprice > 500
ORDER BY 
    od.o_orderdate DESC, 
    sd.nation_name ASC;
