WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        CONCAT(s.s_name, ' (', SUBSTRING(s.s_address, 1, 10), '...)') AS formatted_name_address
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_type, 
        p.p_size, 
        REPLACE(p.p_comment, 'part', 'component') AS modified_comment
    FROM 
        part p
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        RIGHT(c.c_address, 10) AS last_ten_address_digits
    FROM 
        customer c
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
)
SELECT 
    sd.formatted_name_address,
    pd.p_name,
    pd.modified_comment,
    cd.c_name,
    SUM(oli.l_quantity) AS total_quantity,
    SUM(oli.l_extendedprice * (1 - oli.l_discount)) AS total_revenue
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    CustomerDetails cd ON cd.c_custkey = sd.s_nationkey
JOIN 
    OrderLineItems oli ON oli.l_orderkey = pd.p_partkey
GROUP BY 
    sd.formatted_name_address,
    pd.p_name,
    pd.modified_comment,
    cd.c_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
