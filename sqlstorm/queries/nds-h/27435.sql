WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        n.n_name AS nation_name, 
        CONCAT(s.s_name, ' from ', s.s_address, ', ', n.n_name) AS full_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
PartInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_container, 
        p.p_comment, 
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_container LIKE 'Box%'
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        c.c_custkey, 
        c.c_name, 
        c.c_mktsegment, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price,
        COUNT(DISTINCT li.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    si.full_info, 
    pi.p_name, 
    pi.comment_length, 
    od.total_price, 
    od.part_count
FROM 
    SupplierInfo si
JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN 
    PartInfo pi ON ps.ps_partkey = pi.p_partkey
JOIN 
    OrderDetails od ON pi.p_partkey = od.part_count
WHERE 
    od.total_price > 100
ORDER BY 
    si.nation_name, pi.comment_length DESC;
