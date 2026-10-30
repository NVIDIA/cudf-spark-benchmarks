WITH CTE_CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_phone,
        c.c_acctbal,
        LEFT(c.c_comment, 30) AS short_comment
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CTE_PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        ROUND(SUM(ps.ps_availqty), 2) AS total_available_qty,
        ROUND(AVG(p.p_retailprice), 2) AS average_retail_price,
        p.p_comment AS part_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_container, p.p_comment
),
CTE_OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        COUNT(DISTINCT l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, o.o_orderpriority
)
SELECT 
    c.c_name,
    c.nation_name,
    c.region_name,
    p.p_name,
    p.total_available_qty,
    p.average_retail_price,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.o_orderstatus,
    o.o_orderpriority,
    c.short_comment,
    p.part_comment
FROM 
    CTE_CustomerDetails c
JOIN 
    CTE_OrderDetails o ON c.c_custkey = o.o_orderkey
JOIN 
    CTE_PartDetails p ON o.o_orderkey = p.p_partkey
WHERE 
    p.average_retail_price > 50.00
ORDER BY 
    c.nation_name, p.average_retail_price DESC, o.o_orderdate;
