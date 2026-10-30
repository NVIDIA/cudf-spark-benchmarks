
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name,
        r.r_name AS region_name
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
        p.p_container,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20 AND
        p.p_retailprice > 100.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_comment,
        c.c_name AS customer_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice,
        l.l_shipdate,
        l.l_comment
    FROM 
        lineitem l
    WHERE 
        l.l_quantity > 0 AND
        l.l_discount BETWEEN 0.05 AND 0.15
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    pd.p_name,
    ol.o_orderkey,
    ol.o_orderdate,
    SUM(lid.l_extendedprice * (1 - lid.l_discount)) AS total_revenue,
    COUNT(DISTINCT ol.o_orderkey) AS order_count
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    LineItemDetails lid ON pd.p_partkey = lid.l_partkey
JOIN 
    OrderDetails ol ON lid.l_orderkey = ol.o_orderkey
GROUP BY 
    sd.s_name, sd.nation_name, sd.region_name, pd.p_name, ol.o_orderkey, ol.o_orderdate
HAVING 
    SUM(lid.l_extendedprice * (1 - lid.l_discount)) > 5000
ORDER BY 
    total_revenue DESC, sd.s_name;
